#!/usr/bin/env python3
"""
# /// script
# dependencies = [
#   "reportlab",
#   "matplotlib", 
#   "requests",
#   "pillow",
#   "pytz"
# ]
# ///

Linode Infrastructure Billing Report Generator

This script generates a comprehensive PDF billing report for Linode infrastructure,
including cost analysis, resource inventory, and visual diagrams.

Usage: uv run generate_billing_report.py
"""

import json
import subprocess
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import tempfile
import base64

# PDF generation
from reportlab.lib.pagesizes import letter, A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch, cm
from reportlab.lib.colors import Color, HexColor
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
from reportlab.platypus.tableofcontents import TableOfContents
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_RIGHT

# Charts and diagrams
import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import FancyBboxPatch
import numpy as np

# Time handling
import pytz

class LinodeBillingReport:
    def __init__(self):
        self.report_dir = Path("./reports")
        self.report_dir.mkdir(exist_ok=True)
        self.pdf_file = self.report_dir / "bill.pdf"
        self.timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        
        # Styling
        self.primary_color = HexColor("#00A651")  # Linode green
        self.secondary_color = HexColor("#1976D2")  # Blue
        self.accent_color = HexColor("#FF6B35")   # Orange
        self.gray_color = HexColor("#666666")
        
        # Data storage
        self.account_info = {}
        self.linodes = []
        self.lke_clusters = []
        
    def run_linode_cli(self, command: List[str]) -> Optional[Dict]:
        """Run linode-cli command and return JSON result."""
        try:
            cmd = ["linode-cli"] + command + ["--json"]
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
            if result.returncode == 0 and result.stdout.strip():
                data = json.loads(result.stdout)
                return data if isinstance(data, list) and data else None
            return None
        except (subprocess.TimeoutExpired, json.JSONDecodeError, Exception) as e:
            print(f"Warning: Failed to run linode-cli {' '.join(command)}: {e}")
            return None

    def collect_data(self):
        """Collect billing and resource data from Linode CLI."""
        print("📊 Collecting account information...")
        account_data = self.run_linode_cli(["account", "view"])
        if account_data:
            self.account_info = account_data[0]
        
        print("🖥️ Collecting compute resources...")
        linodes_data = self.run_linode_cli(["linodes", "list"])
        if linodes_data:
            self.linodes = linodes_data
            
        print("☸️ Collecting Kubernetes clusters...")
        lke_data = self.run_linode_cli(["lke", "clusters-list"])
        if lke_data:
            self.lke_clusters = lke_data
            
        # Get node pools for each cluster
        for cluster in self.lke_clusters:
            cluster_id = cluster.get('id')
            if cluster_id:
                pools = self.run_linode_cli(["lke", "pools-list", str(cluster_id)])
                cluster['pools'] = pools or []

    def get_instance_cost(self, instance_type: str) -> float:
        """Get monthly cost for instance type."""
        cost_map = {
            "g6-nanode-1": 5.00,
            "g6-standard-1": 12.00,
            "g6-standard-2": 24.00,
            "g6-standard-4": 48.00,
            "g6-standard-6": 96.00,
            "g6-standard-8": 192.00,
            "g6-standard-16": 384.00,
            "g6-standard-20": 480.00,
            "g6-standard-24": 576.00,
            "g6-standard-32": 768.00,
        }
        return cost_map.get(instance_type, 24.00)  # Default to standard-2

    def create_cost_structure_diagram(self) -> str:
        """Create a visual cost structure diagram showing only used components."""
        fig, ax = plt.subplots(figsize=(12, 8))
        ax.set_xlim(0, 10)
        ax.set_ylim(0, 8)
        ax.axis('off')
        
        # Colors
        primary = '#00A651'
        secondary = '#1976D2'
        accent = '#FF6B35'
        
        # Main title
        ax.text(5, 7.5, 'Current Month Cost Breakdown', fontsize=20, fontweight='bold', 
                ha='center', color=primary)
        
        # Account overview box
        balance = self.account_info.get('balance', 0)
        uninvoiced = self.account_info.get('balance_uninvoiced', 0)
        total = float(balance) + float(uninvoiced)
        
        account_box = FancyBboxPatch((0.5, 5.5), 9, 1.5, 
                                   boxstyle="round,pad=0.1", 
                                   facecolor='lightblue', 
                                   edgecolor=secondary, linewidth=2)
        ax.add_patch(account_box)
        
        ax.text(5, 6.5, f'Current Month Usage: ${uninvoiced}', fontsize=14, fontweight='bold', ha='center')
        ax.text(3, 6, f'Balance: ${balance}', fontsize=12, ha='center')
        ax.text(7, 6, f'Total Due: ${total:.2f}', fontsize=12, ha='center', fontweight='bold')
        
        # Only show categories that have active resources
        used_categories = []
        x_positions = []
        
        # Check what's actually being used
        if self.linodes:
            used_categories.append(('Compute Resources', '#FFE0E0'))
            
        if self.lke_clusters:
            used_categories.append(('Kubernetes (LKE)', '#E0F0FF'))
            
        # For now, we'll assume storage and networking are not actively tracked
        # but could be added if we had that data from CLI
        
        # Position categories dynamically based on what's used
        if used_categories:
            spacing = 8 / len(used_categories)
            start_x = spacing / 2 + 1
            
            for i, (name, color) in enumerate(used_categories):
                x = start_x + i * spacing
                x_positions.append(x)
                
                box = FancyBboxPatch((x-0.8, 4.2), 1.6, 1.0,
                                   boxstyle="round,pad=0.05",
                                   facecolor=color, edgecolor='gray')
                ax.add_patch(box)
                ax.text(x, 4.7, name, fontsize=11, ha='center', va='center', fontweight='bold')
        
        # Show details for active compute resources
        if self.linodes and used_categories:
            compute_x = x_positions[0]
            y_pos = 3.8
            
            # Group by instance type and show costs
            type_counts = {}
            for linode in self.linodes:
                instance_type = linode.get('type', 'Unknown')
                type_counts[instance_type] = type_counts.get(instance_type, 0) + 1
            
            for instance_type, count in type_counts.items():
                unit_cost = self.get_instance_cost(instance_type)
                total_cost = unit_cost * count
                if count > 1:
                    ax.text(compute_x, y_pos, f"{count}x {instance_type}", fontsize=9, ha='center', fontweight='bold')
                    y_pos -= 0.25
                    ax.text(compute_x, y_pos, f"${total_cost:.2f}/mo", fontsize=9, ha='center', color=accent)
                else:
                    ax.text(compute_x, y_pos, f"{instance_type}", fontsize=9, ha='center', fontweight='bold')
                    y_pos -= 0.25
                    ax.text(compute_x, y_pos, f"${unit_cost:.2f}/mo", fontsize=9, ha='center', color=accent)
                y_pos -= 0.3
        
        # Show LKE details if clusters exist
        if self.lke_clusters and len(used_categories) > 1:
            lke_x = x_positions[1]
            y_pos = 3.8
            
            ax.text(lke_x, y_pos, "Control Plane: Free", fontsize=9, ha='center', fontweight='bold')
            y_pos -= 0.25
            
            # Show worker node costs
            total_worker_cost = 0
            for cluster in self.lke_clusters:
                for pool in cluster.get('pools', []):
                    pool_type = pool.get('type', 'g6-standard-2')
                    pool_count = pool.get('count', 0)
                    pool_cost = self.get_instance_cost(pool_type) * pool_count
                    total_worker_cost += pool_cost
                    
                    if pool_count > 0:
                        ax.text(lke_x, y_pos, f"{pool_count}x {pool_type} workers", fontsize=9, ha='center')
                        y_pos -= 0.2
                        ax.text(lke_x, y_pos, f"${pool_cost:.2f}/mo", fontsize=9, ha='center', color=accent)
                        y_pos -= 0.3
        
        # Total monthly estimate for used resources
        if self.linodes or self.lke_clusters:
            total_monthly = 0
            
            # Add compute costs
            for linode in self.linodes:
                total_monthly += self.get_instance_cost(linode.get('type', ''))
                
            # Add LKE worker node costs
            for cluster in self.lke_clusters:
                for pool in cluster.get('pools', []):
                    pool_type = pool.get('type', 'g6-standard-2')
                    pool_count = pool.get('count', 0)
                    total_monthly += self.get_instance_cost(pool_type) * pool_count
            
            if total_monthly > 0:
                estimate_box = FancyBboxPatch((2, 1), 6, 1,
                                            boxstyle="round,pad=0.1",
                                            facecolor='lightyellow',
                                            edgecolor=accent, linewidth=2)
                ax.add_patch(estimate_box)
                ax.text(5, 1.7, 'Current Resources Monthly Cost', fontsize=12, fontweight='bold', ha='center')
                ax.text(5, 1.3, f'${total_monthly:.2f}/month', fontsize=14, fontweight='bold', ha='center', color=accent)
        else:
            # No active resources
            ax.text(5, 3, 'No active billable resources this month', fontsize=14, ha='center', style='italic', color='gray')
        
        # Save diagram
        diagram_file = self.report_dir / "cost_structure.png"
        plt.tight_layout()
        plt.savefig(diagram_file, dpi=300, bbox_inches='tight', facecolor='white')
        plt.close()
        
        return str(diagram_file)

    def create_resource_chart(self) -> str:
        """Create a pie chart of resource types."""
        if not self.linodes:
            return None
            
        # Count instance types
        type_counts = {}
        for linode in self.linodes:
            instance_type = linode.get('type', 'Unknown')
            type_counts[instance_type] = type_counts.get(instance_type, 0) + 1
        
        fig, ax = plt.subplots(figsize=(8, 6))
        
        labels = list(type_counts.keys())
        sizes = list(type_counts.values())
        colors = plt.cm.Set3(np.linspace(0, 1, len(labels)))
        
        wedges, texts, autotexts = ax.pie(sizes, labels=labels, autopct='%1.0f%%',
                                         colors=colors, startangle=90)
        
        ax.set_title('Resource Distribution by Instance Type', fontsize=14, fontweight='bold')
        
        # Save chart
        chart_file = self.report_dir / "resource_chart.png"
        plt.tight_layout()
        plt.savefig(chart_file, dpi=300, bbox_inches='tight', facecolor='white')
        plt.close()
        
        return str(chart_file)

    def generate_pdf(self):
        """Generate the PDF report."""
        print("📄 Generating PDF report...")
        
        doc = SimpleDocTemplate(str(self.pdf_file), pagesize=A4,
                              topMargin=1*inch, bottomMargin=1*inch,
                              leftMargin=0.75*inch, rightMargin=0.75*inch)
        
        # Styles
        styles = getSampleStyleSheet()
        title_style = ParagraphStyle(
            'CustomTitle',
            parent=styles['Heading1'],
            fontSize=24,
            textColor=self.primary_color,
            spaceAfter=30,
            alignment=TA_CENTER
        )
        
        heading_style = ParagraphStyle(
            'CustomHeading',
            parent=styles['Heading2'],
            fontSize=16,
            textColor=self.secondary_color,
            spaceBefore=20,
            spaceAfter=10
        )
        
        # Story (content)
        story = []
        
        # Title page
        story.append(Paragraph("Linode Infrastructure Billing Report", title_style))
        story.append(Spacer(1, 0.5*inch))
        
        # Account info
        account_data = [
            ['Account', self.account_info.get('email', 'N/A')],
            ['Report Date', datetime.now().strftime('%B %d, %Y at %H:%M %Z')],
            ['Balance', f"${self.account_info.get('balance', '0')}"],
            ['Uninvoiced Usage', f"${self.account_info.get('balance_uninvoiced', '0')}"],
            ['Total Due', f"${float(self.account_info.get('balance', 0)) + float(self.account_info.get('balance_uninvoiced', 0)):.2f}"]
        ]
        
        account_table = Table(account_data, colWidths=[2*inch, 3*inch])
        account_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), self.primary_color),
            ('TEXTCOLOR', (0, 0), (-1, 0), 'white'),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 12),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), 'lightgrey'),
            ('GRID', (0, 0), (-1, -1), 1, 'black')
        ]))
        
        story.append(account_table)
        story.append(Spacer(1, 0.3*inch))
        
        # Executive Summary
        story.append(Paragraph("Executive Summary", heading_style))
        
        summary_data = [
            ['Metric', 'Value'],
            ['Active Compute Instances', str(len(self.linodes))],
            ['Active Kubernetes Clusters', str(len(self.lke_clusters))],
            ['Current Month Usage', f"${self.account_info.get('balance_uninvoiced', '0')}"],
        ]
        
        if self.linodes:
            total_monthly = sum(self.get_instance_cost(l.get('type', '')) for l in self.linodes)
            summary_data.append(['Est. Monthly Compute Cost', f"${total_monthly:.2f}"])
        
        summary_table = Table(summary_data, colWidths=[3*inch, 2*inch])
        summary_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), self.secondary_color),
            ('TEXTCOLOR', (0, 0), (-1, 0), 'white'),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 12),
            ('GRID', (0, 0), (-1, -1), 1, 'black'),
            ('BACKGROUND', (0, 1), (-1, -1), HexColor('#E3F2FD'))
        ]))
        
        story.append(summary_table)
        story.append(Spacer(1, 0.3*inch))
        
        # Cost Structure Diagram
        diagram_file = self.create_cost_structure_diagram()
        if diagram_file and Path(diagram_file).exists():
            story.append(Paragraph("Cost Structure Analysis", heading_style))
            story.append(Image(diagram_file, width=6*inch, height=4*inch))
            story.append(Spacer(1, 0.2*inch))
        
        # Active Resources
        story.append(Paragraph("Active Compute Resources", heading_style))
        
        if self.linodes:
            resource_data = [['Instance', 'Type', 'Region', 'Status', 'Est. Monthly Cost']]
            for linode in self.linodes:
                cost = self.get_instance_cost(linode.get('type', ''))
                resource_data.append([
                    linode.get('label', 'Unknown'),
                    linode.get('type', 'Unknown'),
                    linode.get('region', 'Unknown'),
                    linode.get('status', 'Unknown'),
                    f"${cost:.2f}"
                ])
            
            resource_table = Table(resource_data, colWidths=[1.5*inch, 1.2*inch, 1.2*inch, 1*inch, 1.1*inch])
            resource_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), self.accent_color),
                ('TEXTCOLOR', (0, 0), (-1, 0), 'white'),
                ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (-1, -1), 10),
                ('GRID', (0, 0), (-1, -1), 1, 'black'),
                ('BACKGROUND', (0, 1), (-1, -1), HexColor('#F0F0F0'))
            ]))
            
            story.append(resource_table)
        else:
            story.append(Paragraph("✅ No active compute instances", styles['Normal']))
        
        story.append(Spacer(1, 0.3*inch))
        
        # Kubernetes Clusters
        story.append(Paragraph("Kubernetes Infrastructure", heading_style))
        
        if self.lke_clusters:
            lke_data = [['Cluster', 'Version', 'Region', 'Node Pools']]
            for cluster in self.lke_clusters:
                pools_info = []
                for pool in cluster.get('pools', []):
                    pools_info.append(f"{pool.get('count', 0)}x {pool.get('type', 'unknown')}")
                pools_str = ", ".join(pools_info) if pools_info else "No pools"
                
                lke_data.append([
                    cluster.get('label', 'Unknown'),
                    cluster.get('k8s_version', 'Unknown'),
                    cluster.get('region', 'Unknown'),
                    pools_str
                ])
            
            lke_table = Table(lke_data, colWidths=[1.5*inch, 1.2*inch, 1.2*inch, 2.1*inch])
            lke_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), self.secondary_color),
                ('TEXTCOLOR', (0, 0), (-1, 0), 'white'),
                ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (-1, -1), 10),
                ('GRID', (0, 0), (-1, -1), 1, 'black'),
                ('BACKGROUND', (0, 1), (-1, -1), HexColor('#E8F5E8'))
            ]))
            
            story.append(lke_table)
        else:
            story.append(Paragraph("✅ No active Kubernetes clusters", styles['Normal']))
        
        # Resource distribution chart
        chart_file = self.create_resource_chart()
        if chart_file and Path(chart_file).exists():
            story.append(Spacer(1, 0.3*inch))
            story.append(Paragraph("Resource Distribution", heading_style))
            story.append(Image(chart_file, width=4*inch, height=3*inch))
        
        # Cost optimization recommendations
        story.append(Spacer(1, 0.3*inch))
        story.append(Paragraph("Cost Optimization Recommendations", heading_style))
        
        recommendations = [
            "• Review instance sizing - ensure resources match actual usage patterns",
            "• Consider shutting down development/testing instances outside business hours",
            "• Implement monitoring and alerting for cost management",
            "• Use Linode's backup service instead of custom solutions for cost efficiency",
            "• Evaluate long-term pricing options for stable workloads",
            "• Regular cleanup of unused volumes, snapshots, and networking resources"
        ]
        
        for rec in recommendations:
            story.append(Paragraph(rec, styles['Normal']))
            story.append(Spacer(1, 0.1*inch))
        
        # Build PDF
        doc.build(story)
        print(f"✅ PDF report generated: {self.pdf_file}")
        
        return str(self.pdf_file)

    def run(self):
        """Main execution function."""
        print("🚀 Starting Linode Billing Report Generation")
        print("=" * 50)
        
        try:
            self.collect_data()
            pdf_path = self.generate_pdf()
            
            print("\n" + "=" * 50)
            print("✅ Report Generation Complete!")
            print(f"📄 PDF Report: {pdf_path}")
            print(f"📁 Reports Directory: {self.report_dir}")
            
            # Print summary
            print(f"\n📊 Account Summary:")
            print(f"   Balance: ${self.account_info.get('balance', '0')}")
            print(f"   Uninvoiced: ${self.account_info.get('balance_uninvoiced', '0')}")
            print(f"   Active Instances: {len(self.linodes)}")
            print(f"   Active Clusters: {len(self.lke_clusters)}")
            
            return pdf_path
            
        except Exception as e:
            print(f"❌ Error generating report: {e}")
            sys.exit(1)

if __name__ == "__main__":
    generator = LinodeBillingReport()
    generator.run()